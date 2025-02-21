import { Injectable } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';
import WagerStatus, { CreateWagerDto } from '../dtos/wager.dto';

@Injectable()
export class WagerService {
  constructor(private readonly prisma: PrismaService) {}

  async createWager(data: CreateWagerDto) {
    return await this.prisma.wager.create({ data });
  }

  async getAllWagers(
    status: WagerStatus,
    hashtags?: string,
    filterType: 'AND' | 'OR' = 'OR',
  ) {
    const hashtagList = hashtags ? hashtags.split(',') : [];

    const query: any = {
      where: {
        status,
      },
      include: {
        hashtags: true,
      },
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
