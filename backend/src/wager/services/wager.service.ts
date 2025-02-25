import { Injectable } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';
import WagerStatus, { CreateWagerDto } from '../dtos/wager.dto';

@Injectable()
export class WagerService {
  constructor(private readonly prisma: PrismaService) {}

  async createWager(payload: CreateWagerDto) {
    return await this.prisma.wager.create({
      data: {
        ...payload,
        hashtags: {
          connect: payload.hashtags.map((name) => ({ name })),
        },
      },
    });
  }

  async getAllWagers(
    status: WagerStatus,
    hashtags?: string,
    filterType: 'AND' | 'OR' = 'OR',
    page?: number,
    limit?: number,
  ) {
    /**
     * use default values if not provided but this is unlikely
     * to happen as we already default the values
     */
    page = page ?? 1;
    limit = limit ?? 10;
    const hashtagList = hashtags ? hashtags.split(',') : [];

    const query: any = {
      where: {
        status,
      },
      include: {
        hashtags: true,
      },
      skip: (page - 1) * limit,
      take: limit,
    };

    if (hashtagList.length > 0) {
      if (filterType === 'AND') {
        query.where.hashtags = {
          every: {
            name: {
              in: hashtagList,
            },
          },
        };
      } else {
        query.where.hashtags = {
          some: {
            name: {
              in: hashtagList,
            },
          },
        };
      }
    }

    return await this.prisma.wager.findMany(query);
  }

  async findOneById(id: string) {
    return await this.prisma.wager.findUnique({
      where: {
        id,
      },
    });
  }
}
