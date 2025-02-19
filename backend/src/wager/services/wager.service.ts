import { Injectable } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';
import WagerStatus, { CreateWagerDto } from '../dtos/wager.dto';

@Injectable()
export class WagerService {
  constructor(private readonly prisma: PrismaService) {}

  async createWager(data: CreateWagerDto) {
    return await this.prisma.wager.create({ data });
  }

  async getAllWagers(status: WagerStatus) {
    return await this.prisma.wager.findMany({ where: { status } });
  }

  async findOneById(id: string) {
    return await this.prisma.wager.findUnique({
      where: {
        id,
      },
    });
  }
}
